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
    let onTap: () -> Void
    
    var body: some View {
        
            VStack(spacing: 16) {
                Image(mentor.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 276, height: 276)
                    .shadow(
                        color: Color.gray.opacity(0.12),
                        radius: 44,
                        x: 0,
                        y: 18
                    )
                
                Text(mentor.name)
                    .font(.system(size: 26))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue500)
                
                Text(mentor.description)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray600)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack{
                    ForEach(mentor.tags, id: \.self){ tag in
                        Text(tag)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.blue500)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(Color.blue50)
                            }
                    }
                }
                
                AcceptButton(labelText:  "멘토 선택", action: onTap)
                
            }
            .frame(maxWidth: .infinity)
            .frame(height: 469)
            .padding(.horizontal, 29)
            .background{
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
            }
            .overlay{
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.gray300)
            }
        }
}

struct MentorCard_Previews: PreviewProvider {
    static var previews: some View {
        MentorCard(
            mentor: Mentor.sampleMentors[0],
            isSelected: true,
            onTap: {}
        )
    }
}
