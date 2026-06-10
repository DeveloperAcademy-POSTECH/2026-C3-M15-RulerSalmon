//
//  MentorCard.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/1/26.
//

import SwiftUI

struct MentorCard: View {
    let mentor: Mentor
    let isSelected: Bool
    
    
    var body: some View {
        
        VStack(spacing: 16) {
            Image(mentor.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160)
                .frame(width: 220, height: 220)
                .background {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(
                                        red: 232.0 / 255.0,
                                        green: 243.0 / 255.0,
                                        blue: 255.0 / 255.0
                                    )
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color.gray600.opacity(0.15),
                            radius: 20,
                            x: 0,
                            y: 20
                        )
                }
                .padding(.top, 12)

            
            Text(mentor.name)
                .font(.system(size: 28))
                .fontWeight(.bold)
                .foregroundStyle(Color.blue500)
            
            Text(mentor.description)
                .font(.system(size: 16))
                .fontWeight(.medium)
                .foregroundStyle(Color.gray600)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
            
            HStack{
                ForEach(mentor.tags, id: \.self){ tag in
                    Text(tag)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.blue500)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Color.blue50)
                        }
                        .overlay {
                            Capsule()
                            .stroke(Color.blue100, lineWidth: 0.5)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white)
                .shadow(
                    color: Color.gray600.opacity(0.15),
                    radius: 20,
                    x: 0,
                    y: 12
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.gray200)
        }
        .padding(.horizontal, 40)
        
    }
}

struct MentorCard_Previews: PreviewProvider {
    static var previews: some View {
        MentorCard(
            mentor: Mentor.sampleMentors[0],
            isSelected: true
        )
    }
}
